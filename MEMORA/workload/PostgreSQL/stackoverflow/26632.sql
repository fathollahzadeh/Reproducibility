WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COALESCE(cnt.CommentCount, 0) AS CommentCount,
        COALESCE(ans.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cnt ON p.Id = cnt.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS PostId,
            COUNT(Id) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ans ON p.Id = ans.PostId
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        SUBSTRING(rp.Body, 1, 200) AS BodySnippet,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        pht.Name AS PostHistoryType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON ph.PostId = rp.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostId IS NOT NULL 
)
SELECT 
    fp.Title,
    fp.BodySnippet,
    fp.ViewCount,
    fp.CommentCount,
    fp.AnswerCount,
    STRING_AGG(DISTINCT fp.Tags, ', ') AS AllTags,
    COUNT(fp.PostId) AS PostHistoryChangeCount,
    MAX(fp.CreationDate) AS LastUpdatedDate
FROM 
    FilteredPosts fp
GROUP BY 
    fp.Title, fp.BodySnippet, fp.ViewCount, fp.CommentCount, fp.AnswerCount
ORDER BY 
    PostHistoryChangeCount DESC,
    LastUpdatedDate DESC;