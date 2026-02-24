
WITH RECURSIVE RecursiveCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId  
),
PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostVoteSummary vs ON p.Id = vs.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, vs.UpVotes, vs.DownVotes
),
FinalResults AS (
    SELECT
        pa.PostId,
        pa.Title,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        u.Reputation,
        ub.BadgeCount,
        ub.BadgeNames,
        CASE 
            WHEN pa.CommentCount > 5 THEN 'Highly Active'
            WHEN pa.CommentCount BETWEEN 3 AND 5 THEN 'Moderately Active'
            ELSE 'Less Active'
        END AS ActivityLevel
    FROM 
        PostActivity pa
    LEFT JOIN 
        Users u ON pa.PostId = u.AccountId
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.Reputation,
    fr.BadgeCount,
    fr.BadgeNames,
    fr.ActivityLevel,
    r.Level AS PostLevel
FROM 
    FinalResults fr
JOIN 
    RecursiveCTE r ON fr.PostId = r.PostId
WHERE 
    fr.UpVotes > fr.DownVotes
ORDER BY 
    fr.UpVotes DESC, fr.CommentCount DESC;
