WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerDisplayName,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerDisplayName, P.PostTypeId
),
TopPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerDisplayName,
        PD.CommentCount,
        PD.TotalBounties,
        ROW_NUMBER() OVER (ORDER BY PD.CommentCount DESC, PD.TotalBounties DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    UB.BadgeCount,
    UB.GoldBadgeCount,
    UB.SilverBadgeCount,
    UB.BronzeBadgeCount,
    TP.Title AS TopPostTitle,
    TP.CreationDate AS PostCreationDate,
    TP.CommentCount AS PostCommentCount,
    TP.TotalBounties AS PostTotalBounties
FROM 
    UserBadges UB
LEFT JOIN 
    TopPosts TP ON UB.UserId = (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = TP.PostId)
WHERE 
    UB.BadgeCount > 0
ORDER BY 
    UB.BadgeCount DESC, 
    TP.CommentCount DESC 
LIMIT 10;