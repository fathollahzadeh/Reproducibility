
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.Score >= (SELECT AVG(Score) FROM Posts)  
      AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'  
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id  
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
TopPostsWithReasons AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerReputation,
        COALESCE(cpr.CloseReasons, ARRAY[]::VARCHAR[]) AS CloseReasons,
        pt.TagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostReasons cpr ON rp.PostId = cpr.PostId
    JOIN 
        PostTagCounts pt ON rp.PostId = pt.PostId
    WHERE 
        rp.Rank = 1  
)
SELECT 
    TPW.PostId,
    TPW.Title,
    TPW.Score,
    TPW.CreationDate,
    TPW.OwnerReputation,
    TPW.CloseReasons,
    TPW.TagCount,
    CASE 
        WHEN TPW.OwnerReputation > 1000 THEN 'Expert'
        ELSE 'Novice'
    END AS UserLevel,
    CONCAT_WS(';', NULLIF(TPW.CloseReasons[1], ''), NULLIF(TPW.CloseReasons[2], '')) AS CloseReasonSnippet,
    CASE 
        WHEN TPW.Score IS NULL THEN 'No Score'
        ELSE CAST(TPW.Score AS TEXT)
    END AS ScoreText
FROM 
    TopPostsWithReasons TPW
WHERE 
    TPW.TagCount > 3  
ORDER BY 
    TPW.Score DESC, 
    TPW.CreationDate DESC
LIMIT 100;
