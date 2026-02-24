WITH RecursiveCTE AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
VoteStats AS (
    
    SELECT 
        p.Id AS PostId,
        u.DisplayName AS UserName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Id IN (SELECT UserId FROM RecursiveCTE)
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
FinalStats AS (
    
    SELECT 
        vs.PostId,
        vs.UserName,
        vs.VoteCount,
        vs.UpVotes,
        vs.DownVotes,
        ph.LastEdited,
        ph.EditComments
    FROM 
        VoteStats vs
    JOIN 
        PostHistoryDetails ph ON vs.PostId = ph.PostId
)

SELECT 
    fs.UserName,
    fs.PostId,
    fs.VoteCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.LastEdited,
    fs.EditComments
FROM 
    FinalStats fs
ORDER BY 
    fs.VoteCount DESC,
    fs.LastEdited DESC;