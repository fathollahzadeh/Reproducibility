WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
CommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
TagsWithExcerpt AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(p.Title) AS ExcerptPostTitle
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    CASE 
        WHEN rp.Score < 0 THEN 'Negative Score'
        WHEN rp.Score = 0 THEN 'Neutral Score'
        ELSE 'Positive Score'
    END AS ScoreCategory,
    t.TagName,
    t.ExcerptPostTitle
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    CommentCounts cc ON rp.PostId = cc.PostId
CROSS JOIN 
    TagsWithExcerpt t
WHERE 
    rp.ScoreRank = 1
    AND (rp.ViewCount IS NOT NULL OR rp.ViewCount > 100)
    AND (rp.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' OR rp.ViewCount < 50)
    AND (t.PostCount > 5 OR t.TagName IS NULL)
ORDER BY 
    rp.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;