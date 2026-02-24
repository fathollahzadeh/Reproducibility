
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId, p.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(us.BadgeCount, 0) AS BadgeCount,
        COALESCE(us.HighestBadgeClass, 0) AS HighestBadgeClass,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS GlobalRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges us ON u.Id = us.UserId
),
PostWithUser AS (
    SELECT 
        ps.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        us.GlobalRank AS OwnerGlobalRank,
        ps.Rank AS PostRank
    FROM 
        PostSummary ps
    JOIN 
        Posts p ON ps.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.ViewCount,
    pw.Score,
    pw.UpVoteCount,
    pw.DownVoteCount,
    pw.CommentCount,
    pw.OwnerDisplayName,
    pw.OwnerReputation,
    pw.OwnerGlobalRank,
    pw.PostRank
FROM 
    PostWithUser pw
WHERE 
    pw.Score > 10
    AND pw.ViewCount BETWEEN 100 AND 10000
    AND pw.Rank = 1
ORDER BY 
    pw.Score DESC, pw.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
