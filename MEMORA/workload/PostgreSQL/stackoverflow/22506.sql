
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id  
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ua.Upvotes,
        ua.Downvotes,
        COALESCE(cpr.CloseReasons, 'No Close Reasons') AS CloseReasons,
        rp.CreationDate
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.PostId = ua.UserId  
    LEFT JOIN 
        ClosedPostReasons cpr ON rp.PostId = cpr.PostId
    WHERE 
        rp.PostRank <= 3  
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.Upvotes,
    fr.Downvotes,
    fr.CloseReasons,
    CASE 
        WHEN fr.CloseReasons = 'No Close Reasons' THEN 'Active' 
        ELSE 'Closed' 
    END AS PostStatus,
    EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - fr.CreationDate)) / 3600 AS AgeInHours
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.Title ASC;
