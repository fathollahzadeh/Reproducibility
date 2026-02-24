
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), p.Id) AS ActivePostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.AcceptedAnswerId, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostAnalytics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Rank,
        r.CommentCount,
        r.UpVotes,
        r.DownVotes,
        u.UserId,
        u.Reputation,
        u.BadgeCount,
        CASE 
            WHEN r.CommentCount > 10 THEN 'Highly Discussed'
            WHEN r.CommentCount > 5 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel
    FROM 
        RankedPosts r
    JOIN 
        UserReputation u ON r.OwnerUserId = u.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Rank,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.Reputation,
    pa.BadgeCount,
    pa.DiscussionLevel,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pa.PostId AND v.VoteTypeId = 6) AS CloseVoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pa.PostId AND ph.PostHistoryTypeId = 10) AS TotalCloseEvents,
    (SELECT STRING_AGG(pht.Name, ', ') 
     FROM PostHistory h
     JOIN PostHistoryTypes pht ON h.PostHistoryTypeId = pht.Id
     WHERE h.PostId = pa.PostId) AS PostHistorySummary
FROM 
    PostAnalytics pa
WHERE 
    pa.Rank <= 5
ORDER BY 
    pa.UpVotes DESC, pa.CommentCount DESC;
