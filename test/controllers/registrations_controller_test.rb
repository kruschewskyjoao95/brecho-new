require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get signup page" do
    get new_registration_path
    assert_response :success
  end

  test "should register a new buyer" do
    assert_difference("User.count") do
      post registrations_path, params: {
        user: {
          name: "Novo Cliente",
          email_address: "cliente@email.com",
          password: "password123",
          role: "buyer"
        }
      }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "should register a new seller with address" do
    assert_difference("User.count") do
      post registrations_path, params: {
        user: {
          name: "Vendedora Nova",
          email_address: "vendedora@email.com",
          password: "password123",
          role: "seller",
          cep: "01001-000",
          address_street: "Praça da Sé",
          address_number: "100",
          address_neighborhood: "Centro",
          address_city: "São Paulo",
          address_state: "SP"
        }
      }
    end

    assert_redirected_to admin_products_path
    assert cookies[:session_id]
    
    new_user = User.last
    assert_equal "seller", new_user.role
    assert_equal "01001-000", new_user.cep
  end

  test "should not register with invalid data" do
    assert_no_difference("User.count") do
      post registrations_path, params: {
        user: {
          name: "",
          email_address: "wrong-email",
          password: "short"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
