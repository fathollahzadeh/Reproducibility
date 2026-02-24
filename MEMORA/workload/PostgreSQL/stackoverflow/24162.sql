
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate BETWEEN '2022-01-01' AND '2023-10-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AcceptanceStatus,
        CASE 
            WHEN rp.CommentCount = 0 THEN 'No Comments'
            WHEN rp.CommentCount < 5 THEN 'Few Comments'
            ELSE 'Many Comments'
        END AS CommentClassification
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
        AND rp.Score > 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.AcceptanceStatus,
    fp.CommentClassification,
    COALESCE(fp.AverageBounty, 0) AS AverageBounty,
    CASE 
        WHEN fp.UpVotesCount - fp.DownVotesCount > 0 THEN 'Positive Feedback'
        WHEN fp.UpVotesCount - fp.DownVotesCount < 0 THEN 'Negative Feedback'
        ELSE 'No Feedback'
    END AS FeedbackStatus
FROM 
    FilteredPosts fp
WHERE 
    fp.CommentClassification IN ('Few Comments', 'Many Comments')
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
