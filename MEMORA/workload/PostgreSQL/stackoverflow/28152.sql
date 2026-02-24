WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COALESCE(v.UpVotes, 0) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, v.UpVotes, v.DownVotes
),

TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.Tags,
        rp.CommentCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)

SELECT 
    tp.Title,
    tp.Tags,
    tp.CommentCount,
    tp.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    TopPosts tp
JOIN 
    Users U ON tp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
ORDER BY 
    tp.Score DESC, 
    tp.CommentCount DESC
LIMIT 10;