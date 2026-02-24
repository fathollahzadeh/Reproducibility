WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS Rank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)
),
AggregateUserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        AnswerCount,
        BadgeCount,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC, AnswerCount DESC) AS UserRank
    FROM 
        AggregateUserReputation
)
SELECT 
    u.DisplayName AS UserName,
    t.UserRank,
    t.NetVotes,
    t.AnswerCount,
    t.BadgeCount,
    COUNT(DISTINCT ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS LastActivityDate,
    STRING_AGG(DISTINCT CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment ELSE 'No comment' END, ', ') AS HistoryComments
FROM 
    TopUsers t
LEFT JOIN 
    Users u ON t.UserId = u.Id
LEFT JOIN 
    RecursivePostHistory ph ON u.Id = ph.UserId
WHERE 
    t.UserRank <= 10
GROUP BY 
    u.DisplayName, t.UserRank, t.NetVotes, t.AnswerCount, t.BadgeCount
ORDER BY 
    t.UserRank;
