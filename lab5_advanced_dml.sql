CREATE TABLE submission_info (
    student_name TEXT,
    student_id TEXT
);
INSERT INTO submission_info VALUES ('Ернұр', '__________');


CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);



INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Aidos', 'Sapin', 25, 50000),
(2, 'Gulnar', 'Aman', 45, 120000);



CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);



INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(101, 'Wireless Mouse', 30.00, 25.00),
(102, 'Keyboard', 45.00, 40.00);



CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);



INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(1001, '2025-10-20', '2025-10-22', 2),
(1002, '2025-11-01', '2025-11-05', 4);



CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);




INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(1, 'aidos@example.com', '+77170001111', '2024-09-01'),
(2, 'gulnar@example.com', NULL, '2025-01-15');



CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);



INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(1, 'Stapler', 50, 3.50, '2025-10-10 10:00:00'),
(2, 'Notebook', 200, 1.20, '2025-10-12 12:00:00');



CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);



INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'aidos', 'aidos@example.com', '2025-01-01 09:00:00'),
(2, 'gulnar', 'gulnar@example.com', '2025-02-01 10:00:00');



CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT uniq_enroll UNIQUE (student_id, course_code, semester)
);



INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 100, 'CS101', 'Fall2025'),
(2, 101, 'CS101', 'Fall2025');




DROP TABLE IF EXISTS users_named;
CREATE TABLE users_named (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);



INSERT INTO users_named (user_id, username, email, created_at) VALUES
(1, 'student1', 's1@example.com', '2025-03-01 08:00:00'),
(2, 'student2', 's2@example.com', '2025-03-02 08:00:00');




CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);



INSERT INTO departments (dept_id, dept_name, location) VALUES
(10, 'Computer Science', 'Building A'),
(20, 'Mathematics', 'Building B'),
(30, 'Economics', 'Building C');



CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);



INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
(100, 1, '2025-09-01', 'A'),
(100, 2, '2025-09-02', 'B'),
(101, 1, '2025-09-01', 'A-');




CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);



INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(1000, 'Alik', 10, '2024-08-01'),
(1001, 'Dana', 20, '2025-02-15');



CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);



CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);



CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);



INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'Gabriel Garcia Marquez', 'Colombia'),
(2, 'Fyodor Dostoevsky', 'Russia'),
(3, 'J.K. Rowling', 'UK');



INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'Penguin Books', 'London'),
(2, 'Vintage', 'New York'),
(3, 'Kazakh Publishing', 'Almaty');



INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(1, 'One Hundred Years of Solitude', 1, 1, 1967, 'ISBN-001-0001'),
(2, 'Crime and Punishment', 2, 2, 1866, 'ISBN-002-0002'),
(3, 'Harry Potter and the Philosopher''s Stone', 3, 3, 1997, 'ISBN-003-0003');



CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);



CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);



CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);



CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);



INSERT INTO categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Books');



INSERT INTO products_fk (product_id, product_name, category_id) VALUES
(10, 'Smartphone', 1),
(11, 'Laptop', 1),
(20, 'Novel', 2);



INSERT INTO orders (order_id, order_date) VALUES
(500, '2025-10-01'),
(501, '2025-10-05');



INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
(900, 500, 10, 1),
(901, 500, 20, 2),
(902, 501, 11, 1);



CREATE TABLE ecommerce_customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);



CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);


CREATE TABLE orders_ecom (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES ecommerce_customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);



CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);



INSERT INTO ecommerce_customers (name, email, phone, registration_date) VALUES
('Aidos Sapin', 'aidos@shop.kz', '+77010001111', '2025-01-10'),
('Gulnar Aman', 'gulnar@shop.kz', '+77012223344', '2025-02-12'),
('Nurlan Bek', 'nurlan@shop.kz', NULL, '2025-03-03'),
('Sara Omar', 'sara@shop.kz', '+77013334455', '2025-04-04'),
('Orken Zhan', 'orken@shop.kz', NULL, '2025-05-05');




INSERT INTO products (name, description, price, stock_quantity) VALUES
('USB Cable', '1m USB-C cable', 5.00, 150),
('Wireless Mouse', 'Optical mouse', 20.00, 80),
('Laptop Stand', 'Aluminum stand', 35.00, 40),
('Notebook A5', '120 pages', 2.50, 500),
('Desk Lamp', 'LED lamp', 18.00, 60);




INSERT INTO orders_ecom (customer_id, order_date, total_amount, status) VALUES
(1, '2025-09-01', 25.00, 'pending'),
(2, '2025-09-05', 40.00, 'processing'),
(1, '2025-10-01', 18.00, 'shipped'),
(3, '2025-10-03', 7.50, 'delivered'),
(4, '2025-10-04', 55.00, 'cancelled');



INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 2, 1, 20.00),
(1, 4, 2, 2.50),
(2, 3, 1, 35.00),
(3, 5, 1, 18.00),
(4, 4, 3, 2.50);
