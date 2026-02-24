
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.RevisionGUID,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(u.Reputation) AS AverageUserReputation,
        MAX(v.CreationDate) AS LastVoteDate,
        SUM(CASE WHEN ph.rn = 1 AND ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS CloseActions
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
FinalResults AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.VoteCount,
        ps.AverageUserReputation,
        pt.TagName,
        ps.LastVoteDate,
        ps.CloseActions
    FROM 
        PostStats ps
    LEFT JOIN 
        PopularTags pt ON ps.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', pt.TagName, '%'))
    WHERE 
        ps.CommentCount > 0
)

SELECT 
    fr.*,
    CASE 
        WHEN fr.CloseActions > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasCloseAction,
    CASE 
        WHEN fr.VoteCount > 50 THEN 'Highly Voted'
        WHEN fr.VoteCount BETWEEN 20 AND 50 THEN 'Moderately Voted'
        ELSE 'Lowly Voted'
    END AS VoteCategory
FROM 
    FinalResults fr
ORDER BY 
    fr.VoteCount DESC, fr.LastVoteDate DESC
LIMIT 100;
