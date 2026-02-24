
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
CommentsStats AS (
    SELECT 
        pc.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts pc
    LEFT JOIN 
        Comments c ON pc.Id = c.PostId
    GROUP BY 
        pc.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.LastActivityDate,
        cps.CommentCount,
        CASE 
            WHEN phs.CloseCount > 0 THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        (SELECT STRING_AGG(pt.TagName, ', ') FROM PopularTags pt 
         WHERE pt.PostCount = (SELECT MAX(PostCount) FROM PopularTags)) AS MostPopularTags,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS RankByScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentsStats cps ON rp.PostId = cps.PostId
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    WHERE 
        rp.PostRank = 1
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.OwnerDisplayName,
    fr.LastActivityDate,
    fr.CommentCount,
    fr.PostStatus,
    fr.MostPopularTags,
    fr.RankByScore
FROM 
    FinalResults fr
WHERE 
    fr.RankByScore <= 10
ORDER BY 
    fr.RankByScore, fr.LastActivityDate DESC;
