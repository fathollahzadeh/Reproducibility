
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.Body,
        PI.Tags,
        PI.OwnerDisplayName,
        PI.CommentCount,
        PI.UpVotes,
        PI.DownVotes,
        U.BadgeCount,
        U.BadgeNames
    FROM 
        PostInfo PI
    JOIN 
        UserBadges U ON PI.OwnerDisplayName = U.DisplayName
    WHERE 
        PI.UpVotes > 10 
    ORDER BY 
        PI.CommentCount DESC, PI.UpVotes DESC
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.Tags,
    FP.OwnerDisplayName,
    FP.CommentCount,
    FP.UpVotes,
    FP.DownVotes,
    FP.BadgeCount,
    FP.BadgeNames
FROM 
    FilteredPosts FP
WHERE 
    FP.BadgeCount > 2;
