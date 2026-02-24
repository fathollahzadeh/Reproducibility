
WITH PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistoryStats AS (
    SELECT 
        Ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(CreationDate) AS LastModified
    FROM 
        PostHistory Ph
    GROUP BY 
        Ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ub.BadgeCount,
    phs.HistoryCount,
    phs.LastModified,
    ps.UpVotes,
    ps.DownVotes
FROM 
    PostStats ps
LEFT JOIN 
    UserBadges ub ON ps.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.ViewCount DESC, 
    ps.Score DESC
LIMIT 100;
