
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRow
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
), RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN ps.CommentCount > 10 THEN 'High Activity'
            WHEN ps.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    WHERE 
        ps.UserPostRow = 1
), FinalResults AS (
    SELECT 
        rp.*,
        COALESCE(rp.UpvoteCount - rp.DownvoteCount, 0) AS NetScore
    FROM 
        RankedPosts rp
)
SELECT 
    f.DisplayName,
    f.Title,
    f.CommentCount,
    f.UpvoteCount,
    f.DownvoteCount,
    f.NetScore,
    f.ActivityLevel
FROM 
    FinalResults f
LEFT JOIN 
    Badges b ON f.PostId = b.UserId
WHERE 
    b.Class = 1 
ORDER BY 
    f.NetScore DESC, 
    f.CommentCount DESC
LIMIT 20;
