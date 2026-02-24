WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 /* Question */
    ORDER BY p.Score DESC
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        COALESCE(com.TotalComments, 0) AS TotalComments,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes
    FROM Users u
    JOIN TopPosts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS TotalComments
        FROM Comments
        GROUP BY PostId
    ) com ON p.PostId = com.PostId
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.PostId = v.PostId
    WHERE p.Rank <= 5 /* Top 5 posts per user */
),
FinalResults AS (
    SELECT 
        ubd.UserId,
        ubd.DisplayName,
        ubd.BadgeCount,
        ubd.GoldBadgeCount,
        ubd.SilverBadgeCount,
        ubd.BronzeBadgeCount,
        p.Title AS PostTitle,
        p.PostCreationDate,
        p.ViewCount,
        p.TotalComments,
        p.TotalUpVotes,
        p.TotalDownVotes
    FROM UserBadges ubd
    JOIN UserPostDetails p ON ubd.UserId = p.UserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    PostTitle,
    PostCreationDate,
    ViewCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM FinalResults
ORDER BY BadgeCount DESC, TotalUpVotes DESC;
