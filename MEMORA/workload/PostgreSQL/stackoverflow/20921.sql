
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        COUNT(*) OVER (PARTITION BY U.Id) AS BadgeCount,
        RANK() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostsRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason,
        PT.Name AS PostType
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) 
),
TopBadgeOwners AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY BadgeCount DESC) AS Rank
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 0
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    O.BadgeName,
    O.BadgeCount,
    P.Title AS MostRecentPost,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes,
    C.CloseReason,
    C.CreationDate AS CloseDate,
    CASE 
        WHEN C.PostId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS IsClosedPost
FROM 
    Users U
LEFT JOIN 
    UserBadges O ON U.Id = O.UserId AND O.BadgeRank = 1 
LEFT JOIN 
    PostActivity P ON U.Id = P.OwnerUserId AND P.RecentPostsRank = 1
LEFT JOIN 
    ClosedPosts C ON P.PostId = C.PostId
WHERE 
    (U.Reputation > 100 OR O.BadgeCount > 0)
    AND (C.PostId IS NULL OR C.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
ORDER BY 
    U.Reputation DESC, O.BadgeCount DESC, P.CommentCount DESC;
