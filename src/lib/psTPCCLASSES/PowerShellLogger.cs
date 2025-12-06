using System;
using System.Collections.Generic;
using System.IO;

namespace psTPCCLASSES;

// Interface for log writers - enables different output targets
public interface ILogWriter
{
     void WriteInfo(string source, string message);
     void WriteWarning(string source, string message);
     void WriteError(string source, string message);
     void WriteVerbose(string source, string message);
}

// Console Writer - writes directly to console (immediately visible in PowerShell)
public class ConsoleLogWriter : ILogWriter
{
     public void WriteInfo(string source, string message)
     {
          Console.WriteLine($"\u001b[36m[INFO]\u001b[0m [{source}] {message}");
     }

     public void WriteWarning(string source, string message)
     {
          Console.WriteLine($"\u001b[33m[WARNING]\u001b[0m [{source}] {message}");
     }

     public void WriteError(string source, string message)
     {
          Console.Error.WriteLine($"\u001b[31m[ERROR]\u001b[0m [{source}] {message}");
     }

     public void WriteVerbose(string source, string message)
     {
          Console.WriteLine($"\u001b[90m[VERBOSE]\u001b[0m [{source}] {message}");
     }
}

// File Writer - writes to log file (thread-safe)
public class FileLogWriter : ILogWriter
{
     private readonly string _logFilePath;
     private readonly object _fileLock = new object();

     public FileLogWriter(string logFilePath)
     {
          _logFilePath = logFilePath;

          var directory = Path.GetDirectoryName(_logFilePath);
          if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
          {
               Directory.CreateDirectory(directory);
          }
     }

     public void WriteInfo(string source, string message)
     {
          WriteToFile("INFO", source, message);
     }

     public void WriteWarning(string source, string message)
     {
          WriteToFile("WARNING", source, message);
     }

     public void WriteError(string source, string message)
     {
          WriteToFile("ERROR", source, message);
     }

     public void WriteVerbose(string source, string message)
     {
          WriteToFile("VERBOSE", source, message);
     }

     private void WriteToFile(string level, string source, string message)
     {
          lock (_fileLock)
          {
               try
               {
                    var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
                    var logLine = $"{timestamp} [{level}] [{source}] {message}\n";
                    File.AppendAllText(_logFilePath, logLine);
               }
               catch
               {
                    // Ignore write errors to prevent exceptions in logging
               }
          }
     }
}

// Main logger class with Singleton pattern
public class PowerShellLogger
{
     // Singleton instance - created on first access
     private static readonly PowerShellLogger _instance = new PowerShellLogger();

     // List of active writers
     private readonly List<ILogWriter> _writers = new List<ILogWriter>();
     private readonly object _writersLock = new object();

     // Singleton access
     public static PowerShellLogger Instance => _instance;

     // Private constructor for Singleton
     private PowerShellLogger()
     {
          // Default: Console writer is active
          _writers.Add(new ConsoleLogWriter());
     }

     // Add writer
     public void AddWriter(ILogWriter writer)
     {
          lock (_writersLock)
          {
               if (!_writers.Contains(writer))
               {
                    _writers.Add(writer);
               }
          }
     }

     // Remove writer
     public void RemoveWriter(ILogWriter writer)
     {
          lock (_writersLock)
          {
               _writers.Remove(writer);
          }
     }

     // Remove all writers of a specific type
     public void RemoveWritersOfType<T>() where T : ILogWriter
     {
          lock (_writersLock)
          {
               _writers.RemoveAll(w => w is T);
          }
     }

     // Enable file logging
     public void EnableFileLogging(string logFilePath)
     {
          lock (_writersLock)
          {
               // Remove old FileWriters
               _writers.RemoveAll(w => w is FileLogWriter);
               // Add new FileWriter
               _writers.Add(new FileLogWriter(logFilePath));
          }
     }

     // Disable file logging
     public void DisableFileLogging()
     {
          lock (_writersLock)
          {
               _writers.RemoveAll(w => w is FileLogWriter);
          }
     }

     // Log methods
     public void Info(string source, string message)
     {
          lock (_writersLock)
          {
               foreach (var writer in _writers)
               {
                    try
                    {
                         writer.WriteInfo(source, message);
                    }
                    catch
                    {
                         // Ignore write errors
                    }
               }
          }
     }

     public void Warning(string source, string message)
     {
          lock (_writersLock)
          {
               foreach (var writer in _writers)
               {
                    try
                    {
                         writer.WriteWarning(source, message);
                    }
                    catch
                    {
                         // Ignore write errors
                    }
               }
          }
     }

     public void Error(string source, string message)
     {
          lock (_writersLock)
          {
               foreach (var writer in _writers)
               {
                    try
                    {
                         writer.WriteError(source, message);
                    }
                    catch
                    {
                         // Ignore write errors
                    }
               }
          }
     }

     public void Verbose(string source, string message)
     {
          lock (_writersLock)
          {
               foreach (var writer in _writers)
               {
                    try
                    {
                         writer.WriteVerbose(source, message);
                    }
                    catch
                    {
                         // Ignore write errors
                    }
               }
          }
     }
}