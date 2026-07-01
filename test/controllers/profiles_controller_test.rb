require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should redirect to login if unauthenticated when editing profile" do
    get edit_profile_path
    assert_redirected_to new_session_path
  end

  test "should get edit profile page when logged in" do
    sign_in_as(@user)
    get edit_profile_path
    assert_response :success
  end

  test "should update profile details" do
    sign_in_as(@user)
    patch profile_path, params: {
      user: {
        name: "Nome Atualizado",
        email_address: "one_updated@example.com"
      }
    }

    assert_redirected_to edit_profile_path
    @user.reload
    assert_equal "Nome Atualizado", @user.name
    assert_equal "one_updated@example.com", @user.email_address
  end

  test "should update seller address details" do
    sign_in_as(@user)
    patch profile_path, params: {
      user: {
        role: "seller",
        cep: "01001-000",
        address_street: "Nova Rua",
        address_number: "456",
        address_neighborhood: "Novo Bairro",
        address_city: "São Paulo",
        address_state: "SP"
      }
    }

    assert_redirected_to edit_profile_path
    @user.reload
    assert_equal "seller", @user.role
    assert_equal "01001-000", @user.cep
    assert_equal "Nova Rua", @user.address_street
  end

  test "should keep existing password if password field is blank" do
    sign_in_as(@user)
    original_password_digest = @user.password_digest

    patch profile_path, params: {
      user: {
        name: "Outro Nome",
        password: ""
      }
    }

    assert_redirected_to edit_profile_path
    @user.reload
    assert_equal original_password_digest, @user.password_digest
    assert_equal "Outro Nome", @user.name
  end
end
