WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.LastActivityDate,
        RANK() OVER (PARTITION BY PH.UserId ORDER BY PH.CreationDate DESC) AS RecentRank
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
BadgesCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
VoteStatistics AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeleteVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(BC.BadgeCount, 0) AS TotalBadges,
    COALESCE(RPH.Title, 'No Recent Activity') AS RecentPostTitle,
    RPH.CreationDate AS RecentPostDate,
    V.UpVotes,
    V.DownVotes,
    V.DeleteVotes,
    CASE 
        WHEN UPC.PostCount = 0 THEN 'New User'
        WHEN U.Reputation < 100 THEN 'Regular User'
        ELSE 'Experienced User'
    END AS UserType
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UPC ON U.Id = UPC.UserId
LEFT JOIN 
    RecentPostHistory RPH ON U.Id = RPH.UserId AND RPH.RecentRank = 1
LEFT JOIN 
    BadgesCounts BC ON U.Id = BC.UserId
LEFT JOIN 
    VoteStatistics V ON V.PostId = RPH.PostId
WHERE 
    U.Reputation > 0
ORDER BY 
    U.Reputation DESC, 
    TotalPosts DESC
LIMIT 100;