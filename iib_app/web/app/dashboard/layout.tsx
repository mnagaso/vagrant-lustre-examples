import Sidebar from '../components/layout/Sidebar';
import Header from '../components/layout/Header';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className="hidden w-64 md:block">
        <Sidebar />
      </div>

      {/* Main content area */}
      <div className="flex w-full flex-col">
        <Header />
        <main className="flex-1 overflow-auto p-6">{children}</main>
      </div>
    </div>
  );
}
