WITH PostCount AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
UserEngagement AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.DisplayName
),
BadgeDistribution AS (
    SELECT 
        B.Class,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.Class
)
SELECT 
    PC.PostType,
    PC.TotalPosts,
    UE.DisplayName,
    UE.TotalComments,
    UE.TotalVotes,
    BD.Class,
    BD.TotalBadges
FROM 
    PostCount PC
JOIN 
    UserEngagement UE ON UE.TotalComments > 0 OR UE.TotalVotes > 0
JOIN 
    BadgeDistribution BD ON BD.TotalBadges > 0
ORDER BY 
    PC.TotalPosts DESC, UE.TotalVotes DESC;
