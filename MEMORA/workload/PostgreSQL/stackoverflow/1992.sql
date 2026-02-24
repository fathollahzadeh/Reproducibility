
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
LatestEdits AS (
    SELECT 
        ph.PostId, 
        ph.UserId AS EditorId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS edit_rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (24, 10) 
)
SELECT 
    us.DisplayName,
    COALESCE(rp.Title, 'N/A') AS LatestQuestionTitle,
    COALESCE(rp.CreationDate, '1970-01-01') AS LastQuestionDate,
    us.QuestionsAsked,
    us.UpVotesReceived,
    us.DownVotesReceived,
    MAX(le.CreationDate) AS LastEditDate
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.Id AND rp.rn = 1
LEFT JOIN 
    LatestEdits le ON us.UserId = le.EditorId AND le.edit_rn = 1
WHERE 
    us.QuestionsAsked > 0
GROUP BY 
    us.DisplayName, rp.Title, rp.CreationDate, us.QuestionsAsked, us.UpVotesReceived, us.DownVotesReceived
ORDER BY 
    us.UpVotesReceived DESC, us.QuestionsAsked DESC
LIMIT 50;
