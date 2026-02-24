WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpVoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        ut.Reputation AS OwnerReputation,
        ut.Rank AS OwnerRank
    FROM 
        RecentPosts rp
    JOIN 
        UserReputation ut ON rp.OwnerDisplayName = ut.DisplayName
),
TopPosts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY Score DESC, CommentCount DESC) AS ScoreRank
    FROM 
        PostDetails
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    CASE 
        WHEN tp.OwnerRank <= 10 THEN 'Top User'
        ELSE 'Normal User'
    END AS UserCategory
FROM 
    TopPosts tp
WHERE 
    tp.ScoreRank <= 10
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;