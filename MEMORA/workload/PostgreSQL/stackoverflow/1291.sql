WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(a.Body, 'No Answer') AS AcceptedAnswerBody,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, a.Body
),
UserPostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.AcceptedAnswerBody,
        upc.PostCount,
        r.DisplayName,
        r.ReputationRank,
        pd.CommentCount,
        pd.TotalBounty
    FROM 
        PostDetails pd
    JOIN 
        Users up ON pd.OwnerUserId = up.Id
    JOIN 
        RankedUsers r ON up.Id = r.UserId
    LEFT JOIN 
        UserPostCounts upc ON upc.OwnerUserId = pd.OwnerUserId
    WHERE 
        pd.CommentCount > 5 AND 
        upc.PostCount IS NOT NULL
)
SELECT 
    fp.*,
    CASE 
        WHEN fp.TotalBounty IS NULL THEN 'No Bounty'
        ELSE CONCAT('Total Bounty: $', fp.TotalBounty)
    END AS BountyStatus
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ReputationRank, fp.CommentCount DESC
LIMIT 10;