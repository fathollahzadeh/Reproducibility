
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
MergedResults AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        SUM(pe.EditCount) AS TotalEdits,
        SUM(pe.EditCount) FILTER (WHERE pe.PostHistoryTypeId = 4) AS TitleEdits,
        SUM(pe.EditCount) FILTER (WHERE pe.PostHistoryTypeId = 5) AS BodyEdits,
        SUM(pe.EditCount) FILTER (WHERE pe.PostHistoryTypeId = 6) AS TagEdits,
        COUNT(DISTINCT rp.PostId) AS RankedPostsCount,
        SUM(ue.UpVotes) AS TotalUpVotes,
        SUM(ue.DownVotes) AS TotalDownVotes
    FROM 
        UserEngagement ue
    JOIN 
        PostHistoryDetails pe ON ue.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = pe.PostId)
    JOIN 
        RankedPosts rp ON ue.UserId = rp.OwnerUserId
    GROUP BY 
        ue.UserId, ue.DisplayName, ue.Reputation
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalEdits,
    TitleEdits,
    BodyEdits,
    TagEdits,
    RankedPostsCount,
    TotalUpVotes,
    TotalDownVotes,
    CASE 
        WHEN TotalEdits IS NULL THEN 'No Edits'
        WHEN TotalEdits > 10 THEN 'Super Editor'
        ELSE 'Editor'
    END AS EditorStatus
FROM 
    MergedResults
WHERE 
    Reputation > 1000
ORDER BY 
    Reputation DESC, TotalEdits DESC
LIMIT 10 OFFSET 0;
