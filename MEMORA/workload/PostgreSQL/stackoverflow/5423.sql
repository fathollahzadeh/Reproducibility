WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVoteCount, 0) AS UpVotes,
        COALESCE(v.DownVoteCount, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.UpVotes,
        rp.DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = rp.PostId) AS AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.AnswerCount,
    DENSE_RANK() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank,
    DENSE_RANK() OVER (ORDER BY pd.UpVotes DESC) AS UpVoteRank
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC
LIMIT 100;
