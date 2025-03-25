export default function Footer() {
  return (
    <footer className="w-full bg-gray-100 dark:bg-gray-900 p-6">
      <div className="container mx-auto">
        <div className="flex flex-col md:flex-row justify-between items-center">
          <div className="mb-4 md:mb-0">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              &copy; {new Date().getFullYear()} IIB GPU Cluster. All rights reserved.
            </p>
          </div>

        </div>
      </div>
    </footer>
  );
}
