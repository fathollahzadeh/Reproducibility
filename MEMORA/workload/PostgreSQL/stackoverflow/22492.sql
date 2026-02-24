WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered' 
            ELSE 'Unanswered' 
        END AS AnswerStatus
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(b.Id) > 0
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT c.UserDisplayName) AS CommentingUsers 
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.AnswerStatus,
    pu.DisplayName AS TopUser,
    pu.BadgeCount,
    pu.TotalUpVotes,
    pu.TotalDownVotes,
    pc.CommentCount,
    pc.CommentingUsers,
    phs.EditCount,
    phs.LastEditedDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
CROSS JOIN 
    (SELECT 
        UserId, 
        DisplayName, 
        BadgeCount, 
        TotalUpVotes, 
        TotalDownVotes 
     FROM 
        TopUsers 
     ORDER BY 
        TotalUpVotes DESC 
     LIMIT 1
    ) pu 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC
LIMIT 10;