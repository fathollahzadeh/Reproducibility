
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons,
        COUNT(DISTINCT ph.UserId) AS VoterCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS int) = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PopularWithComments AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        COALESCE(cp.CloseReasons, 'No closures') AS CloseReasons,
        COALESCE(cp.VoterCount, 0) AS VoterCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    WHERE 
        rp.CommentCount > 5 AND rp.rn = 1
)
SELECT 
    pwc.Id,
    pwc.Title,
    pwc.OwnerDisplayName,
    pwc.CreationDate,
    pwc.Score,
    pwc.CommentCount,
    pwc.CloseReasons,
    pwc.VoterCount
FROM 
    PopularWithComments pwc
ORDER BY 
    pwc.Score DESC,
    pwc.CommentCount DESC;
