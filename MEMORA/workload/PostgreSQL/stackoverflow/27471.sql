WITH UserPostCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank
    FROM 
        UserPostCount
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.QuestionCount,
    T.AnswerCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(B.BadgeNames, 'None') AS BadgeNames,
    COALESCE(A.TotalBounty, 0) AS TotalBounty,
    A.TotalVotes,
    T.PostRank,
    T.QuestionRank
FROM 
    TopUsers T
LEFT JOIN 
    UserBadges B ON T.UserId = B.UserId
LEFT JOIN 
    UserActivity A ON T.UserId = A.UserId
WHERE 
    T.TotalPosts > 10
ORDER BY 
    T.PostRank, T.QuestionRank;
