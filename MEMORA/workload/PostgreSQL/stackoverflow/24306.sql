WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModificationDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ModifiedTypes
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
AnsweredPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        PostLinks pl
    JOIN 
        Posts p ON pl.PostId = p.Id
    WHERE 
        p.PostTypeId = 2  
    GROUP BY 
        pl.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerName,
        rp.Rank,
        rp.AnswerStatus,
        COALESCE(phs.HistoryCount, 0) AS HistoryCount,
        phs.LastModificationDate,
        phs.ModifiedTypes,
        COALESCE(apl.RelatedPostsCount, 0) AS RelatedPostsCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    LEFT JOIN 
        AnsweredPostLinks apl ON rp.PostId = apl.PostId
)
SELECT 
    *,
    (CASE 
        WHEN HistoryCount = 0 THEN 'No History'
        WHEN RelatedPostsCount > 5 THEN 'Popular'
        ELSE 'Average'
    END) AS PostAssessment
FROM 
    FinalResults
WHERE 
    Rank <= 3  
ORDER BY 
    ViewCount DESC NULLS LAST,  
    CreationDate ASC;