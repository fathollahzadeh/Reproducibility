WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        pvs.TotalVotes,
        pvs.UpVotes,
        pvs.DownVotes
    FROM 
        RankedPosts rp
    JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    t.TagName,
    COUNT(tp.PostId) AS PostCount,
    AVG(tp.Score) AS AverageScore,
    AVG(tp.ViewCount) AS AverageViews,
    SUM(tp.TotalVotes) AS TotalVotes,
    SUM(tp.UpVotes) AS TotalUpVotes,
    SUM(tp.DownVotes) AS TotalDownVotes
FROM 
    Tags t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.TagName || '%'
JOIN 
    TopPosts tp ON p.Id = tp.PostId
GROUP BY 
    t.TagName
ORDER BY 
    PostCount DESC
LIMIT 5;