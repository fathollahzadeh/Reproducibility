
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate AS HistoryDate,
        p.Title AS PostTitle,
        p.Body AS PostBody,
        p.LastActivityDate,
        p.OwnerDisplayName,
        ph.UserDisplayName AS EditorName,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
AggregatedHistories AS (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT Comment, '; ') AS CommentsMade,
        STRING_AGG(CONCAT(EditorName, ' edited at ', CAST(HistoryDate AS CHAR)), '; ') AS EditTimeline
    FROM 
        PostHistoryDetails
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.VoteCount,
    rp.CreationDate,
    ur.DisplayName AS UserDisplayName,
    ur.Reputation,
    ah.CommentsMade,
    ah.EditTimeline
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.UserPostRank = 1 AND rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
LEFT JOIN 
    AggregatedHistories ah ON rp.PostId = ah.PostId
ORDER BY 
    rp.CommentCount DESC, rp.VoteCount DESC;
