
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(p.Score, 0) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate AS ClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
RankedPosts AS (
    SELECT 
        ps.*,
        COALESCE(cp.ClosedDate, NULL) AS ClosedPostDate
    FROM 
        PostStats ps
    LEFT JOIN 
        ClosedPosts cp ON ps.PostId = cp.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.BadgeCount,
    rp.UserPostRank,
    CASE 
        WHEN rp.ClosedPostDate IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus,
    COALESCE(rp.UpVotes - rp.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN rp.BadgeCount >= 5 THEN 'High Achiever' 
        ELSE 'New Contributor' 
    END AS UserAchievementLevel
FROM 
    RankedPosts rp
WHERE 
    rp.UserPostRank <= 5
ORDER BY 
    NetVotes DESC, 
    rp.PostId DESC
LIMIT 100;
