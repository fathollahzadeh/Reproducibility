WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
LastEditedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.LastEditDate,
        PH.UserId AS LastEditorId,
        PH.UserDisplayName AS LastEditorName,
        PH.CreationDate AS EditDate,
        COUNT(DISTINCT PH.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory PH ON p.Id = PH.PostId AND PH.PostHistoryTypeId IN (5, 4) 
    WHERE 
        PH.UserId IS NOT NULL
    GROUP BY 
        p.Id, p.LastEditDate, PH.UserId, PH.UserDisplayName, PH.CreationDate
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        COALESCE(pvc.Upvotes, 0) AS Upvotes,
        COALESCE(pvc.Downvotes, 0) AS Downvotes,
        lpe.LastEditorName,
        lpe.EditCount,
        ur.ReputationRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        LastEditedPosts lpe ON rp.PostId = lpe.PostId
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.Upvotes,
    pa.Downvotes,
    pa.LastEditorName,
    pa.EditCount,
    pa.ReputationRank,
    CASE 
        WHEN pa.Upvotes > pa.Downvotes THEN 'Positive'
        WHEN pa.Upvotes < pa.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.AcceptedAnswerId = pa.PostId) AS AcceptedAnswerCount
FROM 
    PostAnalytics pa
WHERE 
    pa.ReputationRank < 10
ORDER BY 
    pa.ViewCount DESC, pa.ReputationRank ASC
LIMIT 100;