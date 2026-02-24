WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE((
            SELECT COUNT(DISTINCT ph1.Id)
            FROM PostHistory ph1
            WHERE ph1.PostId = p.Id AND ph1.PostHistoryTypeId IN (10, 11)
        ), 0) AS CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.ViewCount, u.DisplayName
),

TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CloseReopenCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.Body,
    REPLACE(tq.Tags, '<', '') AS CleanTags, 
    tq.Score,
    tq.ViewCount,
    tq.Author,
    tq.CloseReopenCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tq.PostId AND v.VoteTypeId = 2) AS UpvoteCount, 
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tq.PostId AND v.VoteTypeId = 3) AS DownvoteCount 
FROM 
    TopQuestions tq
ORDER BY 
    tq.CloseReopenCount DESC, tq.Score DESC;