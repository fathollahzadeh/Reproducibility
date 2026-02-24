
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBountyAmount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.PostTypeId, p.Score
), TopPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CommentCount,
        AvgBountyAmount
    FROM 
        RankedPosts
    WHERE 
        RowNum <= 10 
), PostTagData AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id
), PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT(ph.CreationDate::TEXT, ': ', pht.Name), '; ') AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    t.Title,
    t.Author,
    t.CommentCount,
    t.AvgBountyAmount,
    COALESCE(ptd.Tags, 'No tags') AS Tags,
    COALESCE(phs.HistoryDetails, 'No history') AS HistoryDetails
FROM 
    TopPosts t
LEFT JOIN 
    PostTagData ptd ON t.PostId = ptd.PostId
LEFT JOIN 
    PostHistorySummary phs ON t.PostId = phs.PostId
ORDER BY 
    t.AvgBountyAmount DESC;
