import Header from "./components/Header/header";
import Toppage from "./components/Toppage/toppage";
import Footer from "./components/Footer/footer";

export default function Page() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-grow">
        <Toppage />
      </main>
      <Footer />
    </div>
  );
}
