
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CreationDate
), 
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(uv.UpVotes, 0) AS UpVotes,
    COALESCE(uv.DownVotes, 0) AS DownVotes,
    rp.RankScore,
    ts.TagName,
    ts.PostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
LEFT JOIN 
    TagStatistics ts ON rp.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', ts.TagName, '%'))
WHERE 
    rp.RankScore <= 100
ORDER BY 
    rp.RankScore, rp.CreationDate DESC;
