WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
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
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC, pd.CreationDate DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.OwnerDisplayName, 
    rp.CreationDate, 
    rp.LastActivityDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.AnswerCount, 
    rp.CommentCount, 
    rp.UpVotes, 
    rp.DownVotes
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 100
ORDER BY 
    rp.Rank;
