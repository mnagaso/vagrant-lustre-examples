export default function Footer() {
  return (
    <footer className="w-full bg-black dark:bg-black p-6">
      <div className="container mx-auto">
        <div className="flex flex-col md:flex-row justify-between items-center">
          <div className="mb-4 md:mb-0">
            <p className="text-sm text-black dark:text-white">
              &copy; {new Date().getFullYear()} IIB Cluster Interface. All rights reserved.
            </p>
          </div>

        </div>
      </div>
    </footer>
  );
}
