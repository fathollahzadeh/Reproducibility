WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100 
),
CommentedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        pc.CommentCount,
        COALESCE(pc.AvgCommentLength, 0) AS AvgCommentLength
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount,
            AVG(LENGTH(Text)) AS AvgCommentLength
        FROM 
            Comments
        GROUP BY 
            PostId
    ) pc ON rp.PostId = pc.PostId
    WHERE 
        rp.TagRank = 1 
),
FinalResults AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.CreationDate,
        cp.Score,
        cp.ViewCount,
        cp.Body,
        cp.Tags,
        cp.OwnerDisplayName,
        cp.CommentCount,
        cp.AvgCommentLength,
        PH.Comment AS ClosedReason
    FROM 
        CommentedPosts cp
    LEFT JOIN 
        PostHistory PH ON cp.PostId = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    Body,
    Tags,
    OwnerDisplayName,
    CommentCount,
    AvgCommentLength,
    ClosedReason
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;