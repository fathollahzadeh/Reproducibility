
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostFeedback AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        ARRAY_AGG(DISTINCT ph.Comment) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 52, 53)) AS CloseRevisions,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostTypeId,
        rp.AnswerCount,
        rp.ViewCount,
        CASE 
            WHEN ur.Reputation IS NULL THEN 'Unknown'
            WHEN ur.Reputation >= 1000 THEN 'High Reputation'
            ELSE 'Low Reputation'
        END AS ReputationStatus,
        pf.LastEditDate,
        pf.CloseRevisions,
        pf.CommentCount,
        ur.UpVotesReceived,
        ur.DownVotesReceived
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON ur.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId LIMIT 1)
    LEFT JOIN 
        PostFeedback pf ON pf.PostId = rp.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.PostTypeId,
    f.AnswerCount,
    f.ViewCount,
    f.ReputationStatus,
    f.LastEditDate,
    f.CloseRevisions,
    f.CommentCount,
    CASE 
        WHEN f.UpVotesReceived = 0 THEN 'No Upvotes Yet'
        ELSE CAST(f.UpVotesReceived - f.DownVotesReceived AS TEXT) || ' Net Upvotes'
    END AS NetVotes
FROM 
    FinalReport f
WHERE 
    f.CommentCount > 5
ORDER BY 
    f.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
