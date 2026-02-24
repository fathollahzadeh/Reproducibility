WITH UsersWithBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), 

PostScores AS (
    SELECT
        p.Id AS PostId,
        p.Score,
        p.PostTypeId,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
), 

TopPosts AS (
    SELECT
        ps.PostId,
        ps.Score + (ps.UpVotes - ps.DownVotes) AS NetScore,
        ROW_NUMBER() OVER (PARTITION BY ps.PostType ORDER BY (ps.Score + (ps.UpVotes - ps.DownVotes)) DESC) AS Rank
    FROM PostScores ps
    WHERE ps.PostType IN ('Question', 'Answer')
)

SELECT
    u.DisplayName,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    tp.PostId,
    tp.NetScore,
    tp.Rank,
    COALESCE(ph.Comment, 'No comments') AS HistoryComment
FROM UsersWithBadges u
JOIN TopPosts tp ON u.UserId = (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id = tp.PostId
)
LEFT JOIN PostHistory ph ON ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11)  
WHERE u.BadgeCount > 0
AND tp.Rank <= 5
ORDER BY u.BadgeCount DESC, tp.NetScore DESC;