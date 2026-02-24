WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(COALESCE(v.UpVotes, 0)) AS AverageUpVotes,
        AVG(COALESCE(v.DownVotes, 0)) AS AverageDownVotes
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN (
        SELECT 
            p.Id,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Posts p
        LEFT JOIN 
            Votes v ON p.Id = v.PostId
        WHERE 
            p.PostTypeId = 1
        GROUP BY 
            p.Id
    ) v ON p.Id = v.Id
    GROUP BY 
        t.TagName
)
SELECT 
    tp.TagName,
    tp.PostCount,
    tp.AverageUpVotes,
    tp.AverageDownVotes,
    rp.Title AS SamplePostTitle,
    rp.CreationDate AS SamplePostDate,
    rp.Body AS SamplePostBody,
    rp.Tags AS SamplePostTags
FROM 
    TagStatistics tp
LEFT JOIN 
    RankedPosts rp ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || tp.TagName || '%' ORDER BY p.CreationDate DESC LIMIT 1)
WHERE 
    tp.PostCount > 5 
ORDER BY 
    tp.PostCount DESC, 
    tp.AverageUpVotes DESC
LIMIT 10;