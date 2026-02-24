WITH 
    PostVoteCounts AS (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
            COUNT(*) AS TotalVotes
        FROM Votes 
        GROUP BY PostId
    ), 
    PostMetadata AS (
        SELECT 
            p.Id AS PostId,
            p.Title,
            p.Score,
            p.ViewCount,
            COALESCE(ph.Comment, 'No comments') AS LastEditComment,
            ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
            ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC ) AS UserPostRN
        FROM 
            Posts p
        LEFT JOIN 
            PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
        WHERE 
            p.CreationDate >= '2023-01-01'
            AND EXISTS (SELECT 1 FROM PostLinks pl WHERE pl.PostId = p.Id AND pl.LinkTypeId = 1)
    )
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pvc.UpVoteCount,
    pvc.DownVoteCount,
    CASE 
        WHEN pm.RN = 1 THEN 'Latest Post in Type'
        ELSE 'Older Post in Type'
    END AS PostStatus,
    CASE 
        WHEN pm.UserPostRN = 1 THEN 'Most Active User Post'
        ELSE 'Other User Post'
    END AS UserPostStatus,
    CASE 
        WHEN pvc.TotalVotes IS NULL THEN 'No Votes Recorded'
        ELSE 
            CASE 
                WHEN pvc.UpVoteCount > pvc.DownVoteCount THEN 'Positive Feedback'
                ELSE 'Mixed or Negative Feedback'
            END
    END AS Feedback
FROM 
    PostMetadata pm
LEFT JOIN 
    PostVoteCounts pvc ON pm.PostId = pvc.PostId
WHERE 
    pm.RN <= 5
ORDER BY 
    pm.ViewCount DESC, pm.Score DESC;
