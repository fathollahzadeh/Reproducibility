
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
), 
PostWithLatestVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        (SELECT AVG(CAST(v2.VoteTypeId AS FLOAT)) FROM Votes v2 WHERE v2.PostId = p.Id) AS AvgVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.AnswerCount, p.CommentCount
),
PostHistorySummary AS (
    SELECT 
        PostId, 
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LatestEditDate
    FROM 
        RecursivePostHistory
    WHERE 
        rn <= 5
    GROUP BY 
        PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        RANK() OVER (ORDER BY SUM(b.Class) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    pwlv.PostId,
    pwlv.Title,
    pwlv.AnswerCount,
    pwlv.CommentCount,
    pwlv.UpVotes,
    pwlv.DownVotes,
    phs.EditCount,
    phs.LatestEditDate,
    COALESCE(tu.DisplayName, 'No user') AS TopEditor,
    tu.TotalBadges
FROM 
    PostWithLatestVotes pwlv
LEFT JOIN 
    PostHistorySummary phs ON pwlv.PostId = phs.PostId
LEFT JOIN 
    (SELECT * FROM TopUsers WHERE Rank = 1) AS tu ON tu.UserId = (SELECT UserId FROM PostHistory WHERE PostId = pwlv.PostId ORDER BY CreationDate DESC LIMIT 1)
WHERE 
    pwlv.UpVotes - pwlv.DownVotes > 0 OR phs.EditCount > 0
ORDER BY 
    pwlv.UpVotes DESC, phs.LatestEditDate DESC;
