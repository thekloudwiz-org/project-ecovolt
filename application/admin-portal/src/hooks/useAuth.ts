import { useState, useEffect } from 'react'
import { getCurrentUser, signIn, signOut, fetchAuthSession } from 'aws-amplify/auth'

export interface User {
  id: string
  email: string
  groups: string[]
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      const currentUser = await getCurrentUser()
      const session = await fetchAuthSession()
      
      // Check if user is in admin group
      const groups = (session.tokens?.accessToken?.payload['cognito:groups'] as string[]) || []
      const isAdmin = groups.includes('admins')

      if (isAdmin) {
        setUser({
          id: currentUser.userId,
          email: currentUser.signInDetails?.loginId || '',
          groups,
        })
        setIsAuthenticated(true)
      } else {
        // Not an admin, sign out
        await signOut()
        setIsAuthenticated(false)
      }
    } catch (error) {
      setIsAuthenticated(false)
    } finally {
      setIsLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    try {
      const { isSignedIn } = await signIn({ username: email, password })
      
      if (isSignedIn) {
        await checkAuth()
        return { success: true }
      }
      
      return { success: false, error: 'Login failed' }
    } catch (error: any) {
      return { success: false, error: error.message || 'Login failed' }
    }
  }

  const logout = async () => {
    try {
      await signOut()
      setUser(null)
      setIsAuthenticated(false)
    } catch (error) {
      console.error('Logout error:', error)
    }
  }

  return {
    user,
    isAuthenticated,
    isLoading,
    login,
    logout,
  }
}
